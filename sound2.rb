require 'strscan'
class Sound
    def initialize
        begin
            # @formula = ARGV[0]
            @formula = ARGF.readlines.join
            # puts @formula
        rescue
            puts "計算式がありません。"
        end
        @scanner = StringScanner.new(@formula.chomp)
        # @scan = @scanner.scan(/(\d+|[\+\-\*\/()=]|[a-zA-Z]+)*/)
        @keywords = {
            '+' => :add,
            '-' => :sub,
            '*' => :mul,
            '/' => :div,
            '(' => :left_parn,
            ')' => :right_parn,
            'if' => :if,
            'keepon' => :for,
            'visu' => :print,
            'get' => :gets,
            '=' => :equal
        }

        # 計算式
        # p eval(expression) #結果を出力

        p sentences()

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
        p "expression"
        p result
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
        token = get_token
        if token.is_a?(Numeric) # 数字だったら
            result = token
        elsif token == :left_parn #（ だったら
            result = expression()
            token = get_token # 閉じカッコを取り除く(使用しない)
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
                return eval(exp[1]) + eval(exp[2])
            when :sub
                return eval(exp[1]) - eval(exp[2])
            when :mul
                return eval(exp[1]) * eval(exp[2])
            when :div
                begin
                    return eval(exp[1]) / eval(exp[2])
                rescue => e
                    puts e.message
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
        @scan = @scanner.scan(/(\d+|[\+\-\*\/()=]|[a-zA-Z]+)*/)

        if scan =  @scanner.scan(/[\+\-\*\/()=]/) # 符号の場合
            p scan
            return @keywords[scan]

        elsif scan = @scanner.scan(/\d/) # 数字の場合
            # @num = []
            # @num << scan.to_i
            p scan
            # loop do
            #     case scan[0]
            #     when /\d/ # 数字だったら
            #         token = scan[0]
            #         scan = scan[1..-1]
            #         @num << token.to_i
            #     else
            #         @num = @num.join
            #         p @num
            #         break
            #     end
            # end
            return scan

        elsif scan = @scanner.scan(/[a-zA-Z]/) # アルファベット（if, visu, keepon, get,..）の場合
            # @alphabet = []
            # @alphabet << token
            # loop do
            #     case @scan[0]
            #     when /[a-zA-Z]/ # アルファベットだったら
            #         token = @scan[0]
            #         @scan = @scan[1..-1]
            #         @alphabet << token
            #     else
            #         @alphabet = @alphabet.join
            #         p @alphabet
            #         break
            #     end
            # end
            return scan
        end
    end

    # tokenを受け取り、ソースコードの先頭にそれを押し戻す。
    def unget_token()
        p "アンゲットトークン"
        @scanner.unscan
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
        # 代入文、if文、while文、print文、sentences()?
        token = get_token()
        if token == :left_parn #（ だったら
            result = sentences()
            token = get_token # 閉じカッコを取り除く(使用しない)
            if token != :right_parn then# ) なかったら
                raise Exception, "構文エラー" 
            end
        end

        # if文
        if token == :if then

        # for文
        elsif token == :keepon then

        # print文
        elsif token == :visu then

        # 入力
        elsif token == :get then

        # 代入文
        else
            result = get_token()
            if result == :assignment then
                # result = [result, [:variable, token], [:integer, "eval(expression)ができないunget_tokenかな.."]]
                result = [result, [:variable, token], [:integer, expression()]]
                # result = [result, [:variable, token], [:integer, 1]]
                # eval(expression()もできないけど、eval(expression()で呼び出したいtokenがどこかで呼び出されちゃってる
            end
        end
        return result
    end

end

Sound.new