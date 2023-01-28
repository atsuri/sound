require 'strscan'
class Sound
    def initialize
        unless file = ARGV[0]
            raise Exception, "ファイルがありません。"
        end

        @keywords = {
            '+' => :add,
            '-' => :sub,
            '*' => :mul,
            '/' => :div,
            '(' => :left_parn,
            ')' => :right_parn,
            '=' => :equal,
            # '==' => :d_equal,
            '<' => :small,
            # '<=' => :s_equal,
            '>' => :big,
            # '>=' => :b_equal,
            'para' => :para,
            'real' => :real,
            'open' => :open,
            'close' => :close,
            'keepon' => :keepon,
            'visu' => :visu,
            'get' => :get
        }

        read = File.read(file)
        @scanner = StringScanner.new(read)
        p sentences() # Sound
    end

    def expression()
        result = term()
        token = get_token()
        while token == :add or token == :sub
            result = [token, result, term()]
            p result
            token = get_token()
        end

        unget_token()
        return result
    end

    def term()
        result = factor()
        token = get_token()
        while token == :mul or token == :div
            result = [token, result, factor()]
            p result
            token = get_token()
        end

        unget_token()
        return result
    end

    def factor()
        token = get_token()
        if token.is_a?(Numeric) # 数字だったら
            result = token
        elsif token == :left_parn #（ だったら
            result = expression()
            token = get_token() # 閉じカッコを取り除く(使用しない)
            if token != :right_parn # ) なかったら
                raise Exception, "構文エラー"
            else
                # p token
            end
        end

        return result
    end

    def eval(exp)
        if exp.instance_of?(Array)
            case exp[0]
            when :add
                begin
                    return eval(exp[1]) + eval(exp[2])
                rescue => e
                    puts "加算でエラー：#{e.message}"
                end
            when :sub
                begin
                    return eval(exp[1]) - eval(exp[2])
                rescue => e
                    puts "減算でエラー：#{e.message}"
                end
            when :mul
                begin
                    return eval(exp[1]) * eval(exp[2])
                rescue => e
                    puts "乗算でエラー：#{e.message}"
                end
            when :div
                begin
                    return eval(exp[1]) / eval(exp[2])
                rescue => e
                    puts "除算_でエラー：#{e.message}"
                end
            end
        else
            return exp
        end
    end

    def parse()
        expression()
    end

    # ソースコードの先頭から、次のtokenを一つ切り出して返す。
    def get_token()
        if scan = @scanner.scan(/\A*([0-9.]+)/) then #数値だったら
            # p "数値：#{scan}"
            return scan.to_f
        elsif scan = @scanner.scan(/\A*(#{@keywords.keys.map{|t| Regexp.escape(t)}.join('|')})/) then # 予約語だったら
            # p "予約語：#{@keywords[scan]}"
            return @keywords[scan]
        elsif scan = @scanner.scan(/\A[a-zA-Z]+/) then #英字だったら（変数名）
            # p "変数：#{scan}"
            return scan
        elsif scan = @scanner.scan(/\s/) then #改行文字
            scan = get_token()
            # p "改行の次：#{scan}"
            return scan
        end
    end

    # tokenを受け取り、ソースコードの先頭にそれを押し戻す。
    def unget_token()
        if !(@scanner.eos?)
            @scanner.unscan
        end
    end

    # 文列
    def sentences()
        unless s = sentence()
            raise Exception, "あるべき文が見つからない"
        end
        
        result = [:block, s]
        while s = sentence()
            result << s
        end
        return result
    end

    def sentence()
        # 代入文、if文、while文、print文
        if token = para()
            return token
        # elsif token = keepon()
        #     return token
        elsif token = visu()
            return token
        # elsif token = get()
        #     return token
        elsif token = assignment()
            return token
        end
    end

    def assignment()
        result = [:assignment]
        token = get_token()
        unless token.instance_of?(String)
            unget_token()
            return nil
        end

        result << [:variable, token]
        unless get_token() == :equal
            raise Exception, "イコールがない"
        end
        unless token = expression()
            raise Exception, "式がない"
        end
        result << token
    end

    # 出力
    def visu()
        unless get_token() == :visu
            unget_token()
            return nil
        end
        result = [:visu]
        
        token = get_token()
        if token.instance_of?(String)
            result << [:variable, token]
        elsif token.instance_of?(Float)
            unget_token()
            unless token = eval(expression())
                raise Exception, "visu_式がない"
            end
            result << token
        else
            raise Exception, "visu_変数または数値がない"
        end

        result
    end
    
    # 入力
    def get()
        unless get_token() == :get
            unget_token()
            return nil
        end
        result = [:get]
        get = STDIN.gets
        unless get
            rails Exception, "get_入力がない"
        end
        result << get
    end

    # for文
    def keepon(formula, sentence)
        n = formula # n回繰り返す
        sentence # 繰り返したい式
        for i in 0..n.to_i do
            sentence
            # これじゃできなさそう。。
        end
    end

    # if文
    def para()
        # if
        unless get_token() == :para
            unget_token()
            return nil
        end
        result = [:para]
        # 条件式
        unless token = conditions()
            raise Exception, "para_条件式がない"
        end
        result << token

        # then
        unless get_token() == :open
            raise Exception, "para_openがない"
        end

        
        # 式を取り出す
        unless token = sentence()
            raise Exception, "para_文がない"
        end
        result << token
        # 二文以上あった時
        while token = sentence() do
            result << token
        end

        # else
        result2 = [:real]
        if get_token() == :real
            # 式を取り出す
            unless token = sentence()
                raise Exception, "para_real_文がない"
            end
            result2 << token
            # 二文以上あった時
            while token = sentence() do
                result2 << token
            end
        else
            unget_token()
        end

        # end
        unless get_token() == :close
            raise Exception, "para_closeがない"
            # closeの後に改行するか、別の文が続かないとエラーになってしまう。
        end
        
        result + [result2]
    end

    def conditions()
        result = [:conditions]
        token = get_token() #変数
        unless token.instance_of?(String)
            raise Exception, "conditions_変数がない"
        end
        result << [:variable, token]

        token = get_token()
        case token
        when :equal, :small, :big
            token2 = get_token()
            if token2 == :equal then
                token = :d_equal if token == :equal
                token = :b_equal if token == :big
                token = :s_equal if token == :small
                result << [:operator, token]
            else
                unget_token()
                result << [:operator, token]
            end
        else
            raise Exception, "conditions_演算子がない"
        end

        token = get_token()
        if token.instance_of?(String)
            result << [:variable, token]
        elsif token.instance_of?(Float)
            unget_token()
            unless token = eval(expression())
                raise Exception, "conditions_式がない"
            end
            result << token
        else
            raise Exception, "conditions_変数または数値がない"
        end

        result
    end
end


Sound.new